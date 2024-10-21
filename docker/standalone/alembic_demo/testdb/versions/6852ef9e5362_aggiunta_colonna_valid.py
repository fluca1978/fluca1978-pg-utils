"""Aggiunta colonna valid

Revision ID: 6852ef9e5362
Revises: 830e787ba6be
Create Date: 2024-07-24 13:38:43.736922

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '6852ef9e5362'
down_revision: Union[str, None] = '830e787ba6be'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column( 'persona',
                   sa.Column( 'is_valid', sa.Boolean(), server_default = 'true' ) )


def downgrade() -> None:
    op.drop_column( 'persona', 'is_valid' )
